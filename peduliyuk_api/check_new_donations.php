<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $stmt = $conn->prepare("
            SELECT
                d.id AS donation_id,
                u.username
            FROM
                donations d
            JOIN
                users u ON d.id_user = u.id
            WHERE
                d.status = 'Waiting For Approval' AND d.is_new_notification = 1
            ORDER BY
                d.created_at ASC
        ");
        $stmt->execute();
        $result = $stmt->get_result();

        $new_donations = array();
        while ($row = $result->fetch_assoc()) {
            $new_donations[] = $row;
        }

        $response['status'] = 'success';
        $response['message'] = 'Notifikasi donasi baru berhasil diambil.';
        $response['new_donations'] = $new_donations;
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