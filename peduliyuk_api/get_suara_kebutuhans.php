<?php

header('Content-Type: application/json');
include 'db_connect.php';

$response = array();

try {
    $sql = "SELECT sk.*, u.role,
                   COALESCE(ls.organization_name, um.organization_name) AS organization_name,
                   COALESCE(ls.address, um.address) AS address
            FROM suara_kebutuhan sk
            JOIN users u ON sk.user_id = u.id
            LEFT JOIN lembaga_sosial ls ON u.id = ls.user_id AND u.role = 'lembaga_sosial'
            LEFT JOIN umkm um ON u.id = um.user_id AND u.role = 'umkm'";

    $stmt = $conn->prepare($sql);
    $stmt->execute();
    $result = $stmt->get_result();

    $suaraKebutuhan = array();
    while ($row = $result->fetch_assoc()) {
        $suaraKebutuhan[] = $row;
    }

    $response['status'] = 'success';
    $response['suara_kebutuhan'] = $suaraKebutuhan;
} catch (Exception $e) {
    $response['status'] = 'error';
    $response['message'] = 'Terjadi kesalahan: ' . $e->getMessage();
}

echo json_encode($response);
$conn->close();
?>