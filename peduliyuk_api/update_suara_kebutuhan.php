<?php
require_once 'db.php';

header('Content-Type: application/json');

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id = $_POST['id'] ?? null;
    $title = $_POST['title'] ?? null;
    $description = $_POST['description'] ?? null;
    $deadline = $_POST['deadline'] ?? null;
    $image_cleared = $_POST['image_cleared'] ?? '0';

    if (!$id) {
        $response['status'] = 'error';
        $response['message'] = 'Missing suara_kebutuhan ID.';
        echo json_encode($response);
        exit();
    }

    $current_image_url = null;
    $stmt_fetch_image = $conn->prepare("SELECT image_url FROM suara_kebutuhan WHERE id = ?");
    if ($stmt_fetch_image) {
        $stmt_fetch_image->bind_param("i", $id);
        $stmt_fetch_image->execute();
        $result_fetch_image = $stmt_fetch_image->get_result();
        if ($row = $result_fetch_image->fetch_assoc()) {
            $current_image_url = $row['image_url'];
        }
        $stmt_fetch_image->close();
    }

    $image_url_to_save = $current_image_url;

    if (isset($_FILES['image']) && $_FILES['image']['error'] == UPLOAD_ERR_OK) {
        $target_dir = "uploads/suara_kebutuhan/";
        if (!is_dir($target_dir)) {
            mkdir($target_dir, 0777, true);
        }

        $imageFileType = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
        $unique_filename = uniqid('sk_') . '.' . $imageFileType;
        $target_file = $target_dir . $unique_filename;

        $check = getimagesize($_FILES['image']['tmp_name']);
        if ($check === false) {
            $response['status'] = 'error';
            $response['message'] = 'File is not an image.';
            echo json_encode($response);
            exit();
        }

        $allowed_extensions = array("jpg", "jpeg", "png", "gif");
        if (!in_array($imageFileType, $allowed_extensions)) {
            $response['status'] = 'error';
            $response['message'] = 'Sorry, only JPG, JPEG, PNG & GIF files are allowed.';
            echo json_encode($response);
            exit();
        }

        if (move_uploaded_file($_FILES['image']['tmp_name'], $target_file)) {
            if ($current_image_url && file_exists($current_image_url)) {
                unlink($current_image_url);
            }
            $image_url_to_save = $target_file;
        } else {
            $response['status'] = 'error';
            $response['message'] = 'Sorry, there was an error uploading your new image.';
            echo json_encode($response);
            exit();
        }
    } elseif ($image_cleared === '1') {
        if ($current_image_url && file_exists($current_image_url)) {
            unlink($current_image_url);
        }
        $image_url_to_save = null;
    }

    $sql = "UPDATE suara_kebutuhan SET title = ?, description = ?, image_url = ?, deadline = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if ($stmt) {
        $stmt->bind_param("ssssi", $title, $description, $image_url_to_save, $deadline, $id);
        if ($stmt->execute()) {
            $response['status'] = 'success';
            $response['message'] = 'Suara kebutuhan updated successfully.';
        } else {
            $response['status'] = 'error';
            $response['message'] = 'Failed to update suara kebutuhan: ' . $stmt->error;
        }
        $stmt->close();
    } else {
        $response['status'] = 'error';
        $response['message'] = 'Database prepare statement failed: ' . $conn->error;
    }
} else {
    $response['status'] = 'error';
    $response['message'] = 'Invalid request method. Only POST is allowed.';
}

echo json_encode($response);

$conn->close();
?>
