<?php
include 'db.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method. Only POST is allowed.']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);

$donation_acceptance_id = $data['donation_acceptance_id'] ?? null;
$donation_id = $data['donation_id'] ?? null;
$receiver_id = $data['receiver_id'] ?? null;
$rating = $data['rating'] ?? null;
$comment = $data['comment'] ?? null;

if (!$donation_acceptance_id || !$donation_id || !$receiver_id || $rating === null) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required parameters: donation_acceptance_id, donation_id, receiver_id, or rating.']);
    exit;
}

$donation_acceptance_id = $conn->real_escape_string($donation_acceptance_id);
$donation_id = $conn->real_escape_string($donation_id);
$receiver_id = $conn->real_escape_string($receiver_id);
$rating = (int)$rating;
$comment = $conn->real_escape_string($comment);

$conn->begin_transaction();

try {
    $stmt_da = $conn->prepare("UPDATE donation_acceptance SET rating = ?, feedback_comment = ? WHERE id = ?");
    $stmt_da->bind_param("isi", $rating, $comment, $donation_acceptance_id);
    $stmt_da->execute();

    if ($stmt_da->affected_rows === 0 && $stmt_da->errno) {
        throw new Exception("Error updating donation_acceptance feedback: " . $stmt_da->error);
    }

    $stmt_d = $conn->prepare("UPDATE donations SET status = 'Success' WHERE id = ? AND status != 'Success'");
    $stmt_d->bind_param("i", $donation_id);
    $stmt_d->execute();

    if ($stmt_d->affected_rows === 0 && $stmt_d->errno) {
        throw new Exception("Error updating donations status to Success: " . $stmt_d->error);
    }

    if ($stmt_da->affected_rows > 0 || $stmt_d->affected_rows > 0) {
        $conn->commit();
        echo json_encode(['status' => 'success', 'message' => 'Ulasan berhasil dikirim. Donasi selesai.']);
    } else {
        $conn->rollback();
        echo json_encode(['status' => 'error', 'message' => 'Tidak ada perubahan yang diperlukan atau donasi utama sudah Selesai/tidak ditemukan.']);
    }

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Transaksi gagal: ' . $e->getMessage()]);
}

$conn->close();
?>