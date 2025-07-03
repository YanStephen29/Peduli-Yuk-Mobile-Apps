<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    $donation_id = $data['donation_id'] ?? null;
    $clothing_type = $data['clothing_type'] ?? '';
    $size = $data['size'] ?? '';
    $defects = $data['defects'] ?? '';
    $front_photo_url = $data['front_photo_url'] ?? '';
    $back_photo_url = $data['back_photo_url'] ?? '';

    if (empty($donation_id) || empty($clothing_type)) {
        $response['status'] = 'error';
        $response['message'] = 'ID Donasi dan Jenis Pakaian harus diisi.';
        echo json_encode($response);
        exit();
    }

    $conn->begin_transaction();

    try {
        $stmt = $conn->prepare("INSERT INTO pakaian (donation_id, clothing_type, size, defects, front_photo_url, back_photo_url) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("isssss", $donation_id, $clothing_type, $size, $defects, $front_photo_url, $back_photo_url);

        if ($stmt->execute()) {
            $response['status'] = 'success';
            $response['message'] = 'Item pakaian berhasil ditambahkan.';
            $conn->commit();
        } else {
            throw new Exception("Gagal menambahkan item pakaian: " . $stmt->error);
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
