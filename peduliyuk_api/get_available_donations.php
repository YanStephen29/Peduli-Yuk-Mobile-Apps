<?php
header("Content-Type: application/json");
include 'db.php';

$response = array();

if (!isset($_GET['role'])) {
    $response['status'] = 'error';
    $response['message'] = 'Parameter role tidak ditemukan.';
    echo json_encode($response);
    exit();
}

$userRole = $_GET['role'];

$sql = "SELECT
            d.id AS donation_id,
            d.type AS donation_type,
            d.status AS donation_status,
            d.created_at,
            d.accept_to,
            u.id AS user_id,
            u.username,
            u.photo AS user_photo,
            m.address AS user_address,
            CASE
                WHEN d.type = 'barang' THEN (SELECT front_photo_url FROM barang WHERE donation_id = d.id LIMIT 1)
                WHEN d.type = 'pakaian' THEN (SELECT front_photo_url FROM pakaian WHERE donation_id = d.id LIMIT 1)
                ELSE NULL
            END AS first_photo_url,
            CASE
                WHEN d.type = 'barang' THEN (SELECT COUNT(id) FROM barang WHERE donation_id = d.id)
                WHEN d.type = 'pakaian' THEN (SELECT COUNT(id) FROM pakaian WHERE donation_id = d.id)
                ELSE 0
            END AS total_quantity
        FROM
            donations d
        JOIN
            users u ON d.id_user = u.id
        LEFT JOIN
            masyarakat m ON u.id = m.user_id
        WHERE
            d.accept_to = ? AND d.status = 'Waiting For Receiver'";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    $response['status'] = 'error';
    $response['message'] = 'Gagal menyiapkan statement: ' . $conn->error;
    echo json_encode($response);
    exit();
}

$stmt->bind_param("s", $userRole);
$stmt->execute();
$result = $stmt->get_result();

$donations = array();
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $donations[] = $row;
    }
    $response['status'] = 'success';
    $response['donations'] = $donations;
} else {
    $response['status'] = 'success';
    $response['message'] = 'Tidak ada donasi tersedia untuk peran ini.';
    $response['donations'] = [];
}

$stmt->close();
$conn->close();

echo json_encode($response);
?>