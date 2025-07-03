<?php
include 'db.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method. Only POST is allowed.']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);

$user_id = $data['user_id'] ?? null;
$current_password = $data['current_password'] ?? null;
$new_password = $data['new_password'] ?? null;

if (!$user_id || !$current_password || !$new_password) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required parameters.']);
    exit;
}

$user_id = $conn->real_escape_string($user_id);
$current_password_db = $conn->real_escape_string($current_password);
$new_password_db = $conn->real_escape_string($new_password);


$conn->begin_transaction();

try {
    $stmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if (!$user) {
        throw new Exception("User not found.");
    }

    if ($current_password_db !== $user['password']) {
        throw new Exception("Current password is incorrect.");
    }


    $stmt = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
    $stmt->bind_param("si", $new_password_db, $user_id);
    $stmt->execute();

    if ($stmt->affected_rows === 0) {
        throw new Exception("Failed to update password or no changes made.");
    }

    $conn->commit();
    echo json_encode(['status' => 'success', 'message' => 'Password changed successfully.']);

} catch (Exception $e) {
    $conn->rollback();
    error_log("Change password failed: " . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'Failed to change password: ' . $e->getMessage()]);
}

$conn->close();
?>