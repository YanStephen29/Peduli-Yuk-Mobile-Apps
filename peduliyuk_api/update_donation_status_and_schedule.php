<?php
include 'db.php';

header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['donation_acceptance_id']) || !isset($data['donation_id']) || !isset($data['delivery_method']) || !isset($data['scheduled_delivery_date'])) {
    echo json_encode(['status' => 'error', 'message' => 'Parameter yang diperlukan tidak lengkap.']);
    exit;
}

$donation_acceptance_id = $conn->real_escape_string($data['donation_acceptance_id']);
$donation_id = $conn->real_escape_string($data['donation_id']);
$delivery_method = $conn->real_escape_string($data['delivery_method']);
$scheduled_delivery_date = $conn->real_escape_string($data['scheduled_delivery_date']);

$conn->begin_transaction();

try {
    $stmt = $conn->prepare("UPDATE donation_acceptance SET delivery_method = ?, scheduled_delivery_date = ? WHERE id = ?");
    $stmt->bind_param("ssi", $delivery_method, $scheduled_delivery_date, $donation_acceptance_id);
    $stmt->execute();

    $da_affected_rows = $stmt->affected_rows;

    if ($da_affected_rows === 0 && $stmt->errno) {
        throw new Exception("Error updating donation_acceptance: " . $stmt->error);
    }

    $current_date = date('Y-m-d');
    $new_donation_status = 'Found Receiver';

    if ($scheduled_delivery_date === $current_date) {
        $new_donation_status = 'On Delivery';
    }

    $stmt = $conn->prepare("UPDATE donations SET status = ? WHERE id = ?");
    $stmt->bind_param("si", $new_donation_status, $donation_id);
    $stmt->execute();

    $d_affected_rows = $stmt->affected_rows;

    if ($d_affected_rows === 0 && $stmt->errno) {
        throw new Exception("Error updating donation status: " . $stmt->error);
    }

    if ($da_affected_rows > 0 || $d_affected_rows > 0) {
        $conn->commit();
        echo json_encode(['status' => 'success', 'message' => 'Status donasi dan jadwal berhasil diperbarui.']);
    } else {

        $conn->rollback();
        echo json_encode(['status' => 'error', 'message' => 'Tidak ada perubahan yang diperlukan pada data donasi.']);
    }

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Transaksi gagal: ' . $e->getMessage()]);
}

$conn->close();
?>