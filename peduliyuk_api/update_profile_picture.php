<?php
include 'db.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $userId = $_POST['user_id'] ?? '';

    if (empty($userId)) {
        echo json_encode(['status' => 'error', 'message' => 'ID Pengguna tidak diberikan.']);
        exit();
    }

    $uploadDir = 'uploads/profile_pictures/'; // Pastikan direktori ini ada dan dapat ditulis
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    if (isset($_FILES['profile_picture']) && $_FILES['profile_picture']['error'] == UPLOAD_ERR_OK) {
        $fileTmpPath = $_FILES['profile_picture']['tmp_name'];
        $fileName = $_FILES['profile_picture']['name'];
        $fileSize = $_FILES['profile_picture']['size'];
        $fileType = $_FILES['profile_picture']['type'];
        $fileNameCmps = explode(".", $fileName);
        $fileExtension = strtolower(end($fileNameCmps));
        $newFileName = md5(time() . $fileName) . '.' . $fileExtension;
        $destPath = $uploadDir . $newFileName;

        $allowedfileExtensions = array('jpg', 'gif', 'png', 'jpeg');
        if (in_array($fileExtension, $allowedfileExtensions)) {
            if (move_uploaded_file($fileTmpPath, $destPath)) {
                // Update database
                $stmt = $conn->prepare("UPDATE users SET photo = ? WHERE id = ?");
                // Simpan path relatif ke database
                $relativePath = 'uploads/profile_pictures/' . $newFileName;
                $stmt->bind_param("si", $relativePath, $userId);

                if ($stmt->execute()) {
                    echo json_encode(['status' => 'success', 'message' => 'Foto profil berhasil diunggah.', 'image_url' => $relativePath]);
                } else {
                    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan path foto ke database: ' . $stmt->error]);
                }
                $stmt->close();
            } else {
                echo json_encode(['status' => 'error', 'message' => 'Gagal memindahkan file yang diunggah.']);
            }
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Tipe file tidak didukung.']);
        }
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Kesalahan saat mengunggah file: ' . $_FILES['profile_picture']['error']]);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Metode permintaan tidak valid.']);
}

$conn->close();
?>