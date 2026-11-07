"""Original offline exact BODY-surface field interpolation for proxy cages."""
import numpy as np
from scipy.spatial import cKDTree


def nearest_triangle(points, triangles):
    """Closest points/barycentrics for one query against candidate triangles."""
    a, b, c = triangles[:, 0], triangles[:, 1], triangles[:, 2]
    ab, ac, ap = b - a, c - a, points - a
    d00 = np.einsum('ij,ij->i', ab, ab)
    d01 = np.einsum('ij,ij->i', ab, ac)
    d11 = np.einsum('ij,ij->i', ac, ac)
    d20 = np.einsum('ij,ij->i', ap, ab)
    d21 = np.einsum('ij,ij->i', ap, ac)
    den = d00 * d11 - d01 * d01
    good = den > 1e-22
    safe_den = np.where(good, den, 1.)
    u, v = (d11*d20-d01*d21)/safe_den, (d00*d21-d01*d20)/safe_den
    plane_bary = np.stack([1-u-v, u, v], axis=1)
    plane = a + u[:, None]*ab + v[:, None]*ac
    inside = good & (plane_bary.min(axis=1) >= 0)
    locations, barycentrics = [plane], [plane_bary]
    for i, j in [(0, 1), (1, 2), (2, 0)]:
        begin, end = triangles[:, i], triangles[:, j]
        segment = end - begin
        squared = np.einsum('ij,ij->i', segment, segment)
        t = np.clip(np.einsum('ij,ij->i', points-begin, segment)/np.maximum(squared, 1e-24), 0, 1)
        locations.append(begin + t[:, None]*segment)
        bary = np.zeros_like(plane_bary)
        bary[:, i], bary[:, j] = 1-t, t
        barycentrics.append(bary)
    locations = np.stack(locations, axis=1)
    barycentrics = np.stack(barycentrics, axis=1)
    squared_distance = np.sum((locations-points)**2, axis=2)
    squared_distance[~inside, 0] = np.inf
    best = np.argmin(squared_distance, axis=1)
    rows = np.arange(len(best))
    return locations[rows, best], barycentrics[rows, best], squared_distance[rows, best]


def propagate(vertices_m, body_triangles, body_vertex_ids, field, helper_normals=None):
    triangle_ids = np.asarray(body_triangles)
    triangles = vertices_m[triangle_ids]
    centers = triangles.mean(axis=1)
    radii = np.linalg.norm(triangles-centers[:, None], axis=2).max(axis=1)
    radius = float(radii.max())
    tree = cKDTree(centers)
    helpers = sorted(set(range(len(vertices_m))) - set(body_vertex_ids))
    records = []
    for helper in helpers:
        point = vertices_m[helper]
        _, near = tree.query(point, k=16)
        _, _, distance = nearest_triangle(point, triangles[near])
        bound = float(np.sqrt(distance.min()))
        # Exact completeness certificate: any triangle outside this centroid
        # ball is farther than the current nearest surface by the triangle
        # inequality, since radius bounds EVERY triangle's vertex radius.
        candidates = np.array(sorted(tree.query_ball_point(point, bound+radius+1e-10)), dtype=int)
        q, bary, distance = nearest_triangle(point, triangles[candidates])
        best = int(np.argmin(distance))
        source_triangle = int(candidates[best])
        weight = float(bary[best] @ field[triangle_ids[source_triangle]])
        if weight > 1e-10:
            body_face = triangles[source_triangle]
            normal = np.cross(body_face[2]-body_face[0], body_face[1]-body_face[0])
            normal /= max(float(np.linalg.norm(normal)), 1e-20)
            alignment = None
            if helper_normals is not None and np.linalg.norm(helper_normals[helper]) > 1e-12:
                alignment = float(helper_normals[helper] @ normal)
            ties = np.flatnonzero(np.abs(distance-distance[best]) < 1e-14)
            tie_fields = np.array([bary[t] @ field[triangle_ids[candidates[t]]] for t in ties])
            field[helper] = weight
            records.append({'source_helper_vertex': helper, 'source_body_triangle': source_triangle,
                            'source_body_vertex_ids': triangle_ids[source_triangle].tolist(),
                            'barycentric': bary[best].tolist(), 'closest_body_point_m': q[best].tolist(),
                            'helper_body_distance_m': float(np.sqrt(distance[best])), 'neck_weight': weight,
                            'body_outward_normal': normal.tolist(),
                            'signed_helper_to_body_normal_distance_m': float((point-q[best]) @ normal),
                            'helper_body_normal_dot': alignment,
                            'near_tied_source_triangles': candidates[ties].tolist(),
                            'near_tied_field_range': [float(tie_fields.min()), float(tie_fields.max())],
                            'complete_search_centroid_radius_m': bound+radius+1e-10,
                            'tested_source_triangles': len(candidates)})
    return records
