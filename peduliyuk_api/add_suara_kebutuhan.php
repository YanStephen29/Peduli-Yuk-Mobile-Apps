<?php
require_once 'db.php';

header('Content-Type: application/json');

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $user_id = $_POST['user_id'] ?? null;
    $title = $_POST['title'] ?? null;
    $description = $_POST['description'] ?? null;
    $deadline = $_POST['deadline'] ?? null;

    if (!$user_id || !$title || !$description) {
        $response['status'] = 'error';
        $response['message'] = 'Missing required fields (user_id, title, description).';
        echo json_encode($response);
        exit();
    }

    $image_url = null;
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
            $image_url = $target_file;
        } else {
            $response['status'] = 'error';
            $response['message'] = 'Sorry, there was an error uploading your image.';
            echo json_encode($response);
            exit();
        }
    }

    $stmt = $conn->prepare("INSERT INTO suara_kebutuhan (user_id, title, description, image_url, deadline) VALUES (?, ?, ?, ?, ?)");
    if ($stmt) {
        $stmt->bind_param("issss", $user_id, $title, $description, $image_url, $deadline);
        if ($stmt->execute()) {
            $response['status'] = 'success';
            $response['message'] = 'Suara kebutuhan added successfully.';
        } else {
            $response['status'] = 'error';
            $response['message'] = 'Failed to add suara kebutuhan: ' . $stmt->error;
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
