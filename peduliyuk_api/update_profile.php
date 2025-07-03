<?php
include 'db.php';

header("Content-Type: application/json; charset=UTF-8");

$user_id = $_POST['user_id'];
$username = $_POST['username'];
$password = $_POST['password'] ? password_hash($_POST['password'], PASSWORD_DEFAULT) : null;

$update_query = "UPDATE users SET username = '$username'";
if ($password) {
    $update_query .= ", password = '$password'";
}
$update_query .= " WHERE id = '$user_id'";

if (mysqli_query($conn, $update_query)) {
    echo json_encode(['status' => 'success', 'message' => 'Profile berhasil diperbarui']);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui profile']);
}

mysqli_close($conn);
?>