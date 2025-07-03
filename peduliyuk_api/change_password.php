<?php
header('Content-Type: application/json; charset=UTF-8');
include 'db.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $userId = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
    $oldPassword = isset($_POST['old_password']) ? $_POST['old_password'] : '';
    $newPassword = isset($_POST['new_password']) ? $_POST['new_password'] : '';

    if ($userId <= 0 || empty($oldPassword) || empty($newPassword)) {
        echo json_encode(['status' => 'error', 'message' => 'Semua kolom harus diisi.']);
        exit();
    }

    $stmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
    if (!$stmt) {
        echo json_encode(['status' => 'error', 'message' => 'Database error: Gagal menyiapkan statement.']);
        exit();
    }
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();
        $currentHashedPassword = $user['password'];

        if (password_verify($oldPassword, $currentHashedPassword)) {
            $hashedNewPassword = password_hash($newPassword, PASSWORD_DEFAULT);

            $updateStmt = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
            if (!$updateStmt) {
                echo json_encode(['status' => 'error', 'message' => 'Database error: Gagal menyiapkan statement update.']);
                exit();
            }
            $updateStmt->bind_param("si", $hashedNewPassword, $userId);

            if ($updateStmt->execute()) {
                echo json_encode(['status' => 'success', 'message' => 'Password berhasil diperbarui.']);
                exit();
            } else {
                echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui password di database.']);
                exit();
            }
            $updateStmt->close();
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Password lama salah.']);
            exit();
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Pengguna tidak ditemukan.']);
        exit();
    }

    $stmt->close();
    $conn->close();
} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode permintaan tidak valid.']);
    exit();
}
?>