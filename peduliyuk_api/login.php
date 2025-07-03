<?php
include 'db.php';
header("Content-Type: application/json; charset=UTF-8");

if (isset($_POST['email_or_username'], $_POST['password'])) {
    $email_or_username = $_POST['email_or_username'];
    $password = $_POST['password'];

    $stmt = $conn->prepare("SELECT id, email, password, role FROM users WHERE email = ? OR username = ?");
    $stmt->bind_param("ss", $email_or_username, $email_or_username);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();
    $stmt->close();

    if ($user) {
        if (password_verify($password, $user['password'])) {
            echo json_encode([
                "status" => "success",
                "message" => "Login berhasil.",
                "role" => $user['role'],
                "user_id" => (int)$user['id']
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => "Password salah."]);
        }
    } else {
        echo json_encode(["status" => "error", "message" => "Email atau Username tidak ditemukan."]);
    }

    $conn->close();
} else {
    echo json_encode(["status" => "error", "message" => "Email/Username dan Password harus diisi."]);
}
?>