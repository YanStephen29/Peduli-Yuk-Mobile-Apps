<?php
include 'db.php';

header('Content-Type: application/json');

$id = $_POST['id'] ?? null;
$username = $_POST['username'] ?? null;
$no_telp = $_POST['no_telp'] ?? null;
$photo_action = $_POST['photo_action'] ?? 'keep_existing';
$existing_photo_url = $_POST['existing_photo_url'] ?? null;

$newPhotoPath = null;

if (!$id) {
    echo json_encode(['status' => 'error', 'message' => 'Missing admin ID']);
    $conn->close();
    exit();
}

try {
    $oldPhotoQuery = "SELECT photo FROM users WHERE id = ?";
    $stmtOldPhoto = $conn->prepare($oldPhotoQuery);
    $stmtOldPhoto->bind_param("i", $id);
    $stmtOldPhoto->execute();
    $resultOldPhoto = $stmtOldPhoto->get_result();
    $oldPhotoData = $resultOldPhoto->fetch_assoc();
    $oldPhotoDbPath = $oldPhotoData['photo'] ?? null;
    $stmtOldPhoto->close();

    if ($photo_action == 'upload_new' && isset($_FILES['photo']) && $_FILES['photo']['error'] == UPLOAD_ERR_OK) {
        $uploadDir = 'assets/uploads/';

        if (!is_dir($uploadDir)) {
            if (!mkdir($uploadDir, 0777, true)) {
                echo json_encode(['status' => 'error', 'message' => 'Failed to create upload directory.']);
                $conn->close();
                exit();
            }
        }

        $imageFileType = strtolower(pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION));
        $uniqueFileName = uniqid() . '.' . $imageFileType;
        $uploadPath = $uploadDir . $uniqueFileName;

        if (move_uploaded_file($_FILES['photo']['tmp_name'], $uploadPath)) {
            $newPhotoPath = $uploadPath;
            if ($oldPhotoDbPath && $oldPhotoDbPath != $newPhotoPath && file_exists($oldPhotoDbPath)) {
                unlink($oldPhotoDbPath);
            }
        } else {
            echo json_encode(['status' => 'error', 'message' => 'Failed to upload new photo.']);
            $conn->close();
            exit();
        }
    } elseif ($photo_action == 'keep_existing') {
        $newPhotoPath = $oldPhotoDbPath;
    } elseif ($photo_action == 'clear_photo') {
        if ($oldPhotoDbPath && file_exists($oldPhotoDbPath)) {
            unlink($oldPhotoDbPath);
        }
        $newPhotoPath = null;
    }

    $query = "UPDATE users SET username = ?, no_telp = ?, photo = ? WHERE id = ? AND role = 'admin'";
    $stmt = $conn->prepare($query);

    if (!$stmt) {
        echo json_encode(['status' => 'error', 'message' => 'Failed to prepare statement: ' . $conn->error]);
        $conn->close();
        exit();
    }

    $stmt->bind_param("sssi", $username, $no_telp, $newPhotoPath, $id);
    $stmt->execute();

    if ($stmt->affected_rows > 0) {
        echo json_encode(['status' => 'success', 'message' => 'Profile updated successfully']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'No changes made or admin ID not found.']);
    }

    $stmt->close();

} catch (Exception $e) {
    echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $e->getMessage()]);
}

$conn->close();
?>