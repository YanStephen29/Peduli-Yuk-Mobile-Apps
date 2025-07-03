<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $stmt = $conn->prepare("
            SELECT
                d.id AS donation_id,
                d.type AS donation_type,
                d.created_at AS donation_created_at,
                u.id AS user_id,
                u.username,
                u.no_telp,
                u.photo AS user_photo_url
            FROM
                donations d
            JOIN
                users u ON d.id_user = u.id
            WHERE
                d.status = 'Waiting For Approval'
            ORDER BY
                d.created_at ASC
        ");
        $stmt->execute();
        $result = $stmt->get_result();

        $pending_donations = array();
        while ($row = $result->fetch_assoc()) {
            $pending_donations[] = $row;
        }

        $response['status'] = 'success';
        $response['message'] = 'Permintaan donasi tertunda berhasil diambil.';
        $response['pending_donations'] = $pending_donations;
        $stmt->close();

    } catch (Exception $e) {
        $response['status'] = 'error';
        $response['message'] = $e->getMessage();
    }
} else {
    $response['status'] = 'error';
    $response['message'] = 'Metode request tidak diizinkan. Metode yang diterima: GET';
}

echo json_encode($response);
$conn->close();
?>