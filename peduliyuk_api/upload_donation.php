<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();


if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    $data = json_decode(file_get_contents("php://input"), true);

    $donation_type = $data['donation_type'] ?? '';
    $id_user = $data['id_user'] ?? null;

    if (empty($donation_type) || !in_array($donation_type, ['pakaian', 'barang'])) {
        $response['status'] = 'error';
        $response['message'] = 'Jenis donasi tidak valid.';
        echo json_encode($response);
        exit();
    }

    if (empty($id_user)) {
        $response['status'] = 'error';
        $response['message'] = 'ID Pengguna harus disediakan.';
        echo json_encode($response);
        exit();
    }

    $conn->begin_transaction();

    try {
        $stmt = $conn->prepare("INSERT INTO donations (type, id_user, is_new_notification) VALUES (?, ?, 1)");
        $stmt->bind_param("si", $donation_type, $id_user);

        if ($stmt->execute()) {
            $donation_id = $conn->insert_id;
            $response['status'] = 'success';
            $response['message'] = 'Donasi berhasil dimulai.';
            $response['donation_id'] = $donation_id;
            $conn->commit();
        } else {
            throw new Exception("Gagal memulai donasi: " . $stmt->error);
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