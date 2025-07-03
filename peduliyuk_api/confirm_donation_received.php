<?php
include 'db.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method. Only POST is allowed.']);
    exit;
}

$donation_acceptance_id = $_POST['donation_acceptance_id'] ?? null;
$donation_id = $_POST['donation_id'] ?? null;
$receiver_id = $_POST['receiver_id'] ?? null;
$received_date = $_POST['received_date'] ?? date('Y-m-d H:i:s');

if (!$donation_acceptance_id || !$donation_id || !$receiver_id) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required parameters: donation_acceptance_id, donation_id or receiver_id.']);
    exit;
}

$donation_acceptance_id = $conn->real_escape_string($donation_acceptance_id);
$donation_id = $conn->real_escape_string($donation_id);
$receiver_id = $conn->real_escape_string($receiver_id);
$received_date = $conn->real_escape_string($received_date);

$upload_dir = 'uploads/received_photos/';
if (!is_dir($upload_dir)) {
    mkdir($upload_dir, 0777, true);
}

$photo_path = null;
if (isset($_FILES['photo']) && $_FILES['photo']['error'] == UPLOAD_ERR_OK) {
    $file_tmp_name = $_FILES['photo']['tmp_name'];
    $file_name = uniqid('received_') . '_' . basename($_FILES['photo']['name']);
    $destination = $upload_dir . $file_name;

    if (move_uploaded_file($file_tmp_name, $destination)) {
        $photo_path = $destination;
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to move uploaded file.']);
        exit;
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Photo file is required for confirmation.']);
    exit;
}


$conn->begin_transaction();

try {
    $stmt_da = $conn->prepare("UPDATE donation_acceptance SET received_at = ?, received_photo_url = ? WHERE id = ?");
    $stmt_da->bind_param("ssi", $received_date, $photo_path, $donation_acceptance_id);
    $stmt_da->execute();

    if ($stmt_da->affected_rows === 0 && $stmt_da->errno) {
        throw new Exception("Error updating donation_acceptance: " . $stmt_da->error);
    }

    $stmt_d = $conn->prepare("UPDATE donations SET status = 'Received' WHERE id = ? AND status != 'Success'");
    $stmt_d->bind_param("i", $donation_id);
    $stmt_d->execute();

    if ($stmt_d->affected_rows === 0 && $stmt_d->errno) {
        throw new Exception("Error updating donations status: " . $stmt_d->error);
    }

    if ($stmt_da->affected_rows > 0 || $stmt_d->affected_rows > 0) {
        $conn->commit();
        echo json_encode(['status' => 'success', 'message' => 'Donasi berhasil dikonfirmasi diterima.', 'received_photo_url' => $photo_path]);
    } else {
        $conn->rollback();
        if ($photo_path && file_exists($photo_path)) {
            unlink($photo_path);
        }
        echo json_encode(['status' => 'error', 'message' => 'Tidak ada perubahan yang diperlukan atau donasi utama sudah Selesai/tidak ditemukan.']);
    }

} catch (Exception $e) {
    $conn->rollback();
    if ($photo_path && file_exists($photo_path)) {
        unlink($photo_path);
    }
    echo json_encode(['status' => 'error', 'message' => 'Transaksi gagal: ' . $e->getMessage()]);
}

$conn->close();
?>