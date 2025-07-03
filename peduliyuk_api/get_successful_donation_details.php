<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();
if ($_SERVER['REQUEST_METHOD'] === 'POST' || $_SERVER['REQUEST_METHOD'] === 'GET') {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $data = json_decode(file_get_contents("php://input"), true);
        $donation_id = $data['donation_id'] ?? null;
    } else {
        $donation_id = $_GET['donation_id'] ?? null;
    }

    if (empty($donation_id)) {
        $response['status'] = 'error';
        $response['message'] = 'ID Donasi tidak disediakan.';
        echo json_encode($response);
        exit();
    }

    try {
        $stmt = $conn->prepare("
            SELECT
                d.id AS donation_id,
                d.type AS donation_type,
                d.status AS donation_status,
                d.created_at AS donation_created_at,
                da.id AS acceptance_id,
                da.tanggal_pengambilan,
                da.delivery_method,
                da.scheduled_delivery_date,
                da.received_at,
                da.received_photo_url,
                da.feedback_comment,
                da.rating AS feedback_rating, -- <-- TAMBAHKAN BARIS INI
                u.username AS receiver_username,
                (SELECT p.front_photo_url FROM pakaian p WHERE p.donation_id = d.id LIMIT 1) AS clothing_front_photo_url,
                (SELECT b.front_photo_url FROM barang b WHERE b.donation_id = d.id LIMIT 1) AS item_front_photo_url,
                (SELECT p.clothing_type FROM pakaian p WHERE p.donation_id = d.id LIMIT 1) AS clothing_type,
                (SELECT b.item_name FROM barang b WHERE b.donation_id = d.id LIMIT 1) AS item_name
            FROM
                donations d
            INNER JOIN
                donation_acceptance da ON d.id = da.id_donation
            INNER JOIN
                users u ON da.id_receiver = u.id
            WHERE
                d.id = ?
                AND d.status = 'Success'
                AND da.received_at IS NOT NULL
            ORDER BY
                da.received_at DESC
            LIMIT 1
        ");
        $stmt->bind_param("i", $donation_id);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $donation_detail = $result->fetch_assoc();
            $response['status'] = 'success';
            $response['message'] = 'Detail donasi berhasil diambil.';
            $response['donation_detail'] = $donation_detail;
        } else {
            $response['status'] = 'error';
            $response['message'] = 'Donasi tidak ditemukan, belum berstatus Success, atau belum ada penerimaan yang tercatat.';
        }
        $stmt->close();

    } catch (Exception $e) {
        $response['status'] = 'error';
        $response['message'] = $e->getMessage();
    }
} else {
    $response['status'] = 'error';
    $response['message'] = 'Metode request tidak diizinkan.';
}

echo json_encode($response);
$conn->close();
?>