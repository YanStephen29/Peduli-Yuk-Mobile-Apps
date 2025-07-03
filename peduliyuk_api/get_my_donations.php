<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    $user_id = $data['user_id'] ?? null;

    if (empty($user_id)) {
        $response['status'] = 'error';
        $response['message'] = 'ID Pengguna tidak disediakan.';
        echo json_encode($response);
        exit();
    }

    try {
        $stmt = $conn->prepare("
            SELECT
                d.id,
                d.type,
                d.status,
                d.created_at,
                (SELECT p.front_photo_url FROM pakaian p WHERE p.donation_id = d.id LIMIT 1) AS clothing_front_photo_url,
                (SELECT p.clothing_type FROM pakaian p WHERE p.donation_id = d.id LIMIT 1) AS clothing_type,
                (SELECT p.size FROM pakaian p WHERE p.donation_id = d.id LIMIT 1) AS clothing_size,
                (SELECT p.defects FROM pakaian p WHERE p.donation_id = d.id LIMIT 1) AS clothing_defects,
                (SELECT b.front_photo_url FROM barang b WHERE b.donation_id = d.id LIMIT 1) AS item_front_photo_url,
                (SELECT b.item_name FROM barang b WHERE b.donation_id = d.id LIMIT 1) AS item_name,
                (SELECT b.size FROM barang b WHERE b.donation_id = d.id LIMIT 1) AS item_size,
                (SELECT b.defects FROM barang b WHERE b.donation_id = d.id LIMIT 1) AS item_defects
            FROM
                donations d
            WHERE
                d.id_user = ?
                AND d.status != 'Success'
            ORDER BY
                d.created_at DESC
        ");
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();

        $donations = array();
        while ($row = $result->fetch_assoc()) {
            $donations[] = $row;
        }

        $response['status'] = 'success';
        $response['message'] = 'Donasi berhasil diambil.';
        $response['donations'] = $donations;
        $stmt->close();

    } catch (Exception $e) {
        $response['status'] = 'error';
        $response['message'] = $e->getMessage();
    }
} else {
    $response['status'] = 'error';
    $response['message'] = 'Metode request tidak diizinkan. Metode yang diterima: ' . $_SERVER['REQUEST_METHOD'];
}

echo json_encode($response);
$conn->close();
?>
