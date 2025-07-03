<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    $donation_ids = $data['donation_ids'] ?? [];

    if (empty($donation_ids)) {
        $response['status'] = 'error';
        $response['message'] = 'Tidak ada ID donasi yang disediakan.';
        echo json_encode($response);
        exit();
    }

    $placeholders = implode(',', array_fill(0, count($donation_ids), '?'));
    $types = str_repeat('i', count($donation_ids));

    try {
        $stmt = $conn->prepare("UPDATE donations SET is_new_notification = 0 WHERE id IN ($placeholders)");
        $stmt->bind_param($types, ...$donation_ids);
        $stmt->execute();

        if ($stmt->affected_rows > 0) {
            $response['status'] = 'success';
            $response['message'] = $stmt->affected_rows . ' donasi berhasil ditandai sebagai sudah dilihat.';
        } else {
            $response['status'] = 'info';
            $response['message'] = 'Tidak ada donasi yang perlu ditandai atau sudah ditandai.';
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