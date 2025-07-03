<?php
include 'db.php';

header('Content-Type: application/json');

if (!isset($_GET['user_id'])) {
    echo json_encode(['status' => 'error', 'message' => 'User ID is required.']);
    exit;
}

$user_id = $conn->real_escape_string($_GET['user_id']);

$sql = "
    SELECT
        u.id,
        u.email,
        u.username,
        u.photo,
        u.no_telp,
        u.role,
        -- Detail tambahan berdasarkan peran
        CASE
            WHEN u.role = 'masyarakat' THEN m.age
            ELSE NULL
        END AS age,
        CASE
            WHEN u.role = 'masyarakat' THEN m.address
            WHEN u.role = 'umkm' THEN um.address
            WHEN u.role = 'lembaga_sosial' THEN ls.address
            ELSE NULL
        END AS address,
        CASE
            WHEN u.role = 'umkm' THEN um.organization_name
            WHEN u.role = 'lembaga_sosial' THEN ls.organization_name
            ELSE NULL
        END AS organization_name,
        CASE
            WHEN u.role = 'umkm' THEN um.position_id
            WHEN u.role = 'lembaga_sosial' THEN ls.position_id
            ELSE NULL
        END AS position_id,
        
        -- ## BAGIAN YANG DITAMBAHKAN (2) ##
        p.name AS position_name
        
    FROM
        users u
    LEFT JOIN
        masyarakat m ON u.id = m.user_id AND u.role = 'masyarakat'
    LEFT JOIN
        umkm um ON u.id = um.user_id AND u.role = 'umkm' -- diubah ke huruf kecil
    LEFT JOIN
        lembaga_sosial ls ON u.id = ls.user_id AND u.role = 'lembaga_sosial'
    LEFT JOIN
        position p ON p.id = COALESCE(um.position_id, ls.position_id)
        
    WHERE
        u.id = '$user_id'
    LIMIT 1;
";

$result = $conn->query($sql);

if (!$result) {
    error_log("SQL Error in get_user_profile.php: " . $conn->error);
    echo json_encode(['status' => 'error', 'message' => 'Database query failed: ' . $conn->error]);
    exit;
}

if ($result->num_rows > 0) {
    $profile_data = $result->fetch_assoc();
    echo json_encode(['status' => 'success', 'data' => $profile_data]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'User not found.']);
}

$conn->close();
?>