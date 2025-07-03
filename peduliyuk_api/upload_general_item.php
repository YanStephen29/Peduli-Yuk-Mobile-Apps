<?php
header('Content-Type: application/json');
require_once 'db.php';

$response = array();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    $donation_id = $data['donation_id'] ?? null;
    $item_name = $data['item_name'] ?? '';
    $size = $data['size'] ?? '';
    $defects = $data['defects'] ?? '';
    $front_photo_url = $data['front_photo_url'] ?? '';
    $back_photo_url = $data['back_photo_url'] ?? '';

    if (empty($donation_id) || empty($item_name)) {
        $response['status'] = 'error';
        $response['message'] = 'ID Donasi dan Nama Barang harus diisi.';
        echo json_encode($response);
        exit();
    }

    $conn->begin_transaction();

    try {
        $stmt = $conn->prepare("INSERT INTO barang (donation_id, item_name, size, defects, front_photo_url, back_photo_url) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("isssss", $donation_id, $item_name, $size, $defects, $front_photo_url, $back_photo_url);

        if ($stmt->execute()) {
            $response['status'] = 'success';
            $response['message'] = 'Item barang berhasil ditambahkan.';
            $conn->commit();
        } else {
            throw new Exception("Gagal menambahkan item barang: " . $stmt->error);
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