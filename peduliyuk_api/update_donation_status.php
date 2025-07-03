<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    $donation_id = $data['donation_id'] ?? null;
    $accept_to = $data['accept_to'] ?? null;

    if (empty($donation_id) || empty($accept_to)) {
        $response['status'] = 'error';
        $response['message'] = 'ID Donasi dan target penerima harus disediakan.';
        echo json_encode($response);
        exit();
    }

    $conn->begin_transaction();

    try {
        $stmt = $conn->prepare("UPDATE donations SET status = ?, accept_to = ? WHERE id = ?");
        $new_status = 'Waiting For Receiver';
        $stmt->bind_param("ssi", $new_status, $accept_to, $donation_id);

        if ($stmt->execute()) {
            $response['status'] = 'success';
            $response['message'] = 'Status donasi berhasil diperbarui.';
            $conn->commit();
        } else {
            throw new Exception("Gagal memperbarui donasi: " . $stmt->error);
        }

        $stmt->close();
    } catch (Exception $e) {
        $conn->rollback(); 
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