<?php
include 'db.php';
header("Content-Type: application/json; charset=UTF-8");

if (!isset($_GET['user_id'])) {
    echo json_encode(["status" => "error", "message" => "user_id tidak disediakan."]);
    exit();
}

$userId = (int)$_GET['user_id'];


$stmt = $conn->prepare("SELECT username, photo, role FROM users WHERE id = ?");
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

if ($user) {
    echo json_encode([
        "status" => "success",
        "data" => $user
    ]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Pengguna dengan ID $userId tidak ditemukan."
    ]);
}

$stmt->close();
$conn->close();
?>