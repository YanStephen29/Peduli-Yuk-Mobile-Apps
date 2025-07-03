<?php
require_once 'db.php';

header('Content-Type: application/json');

$response = array();

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $id = $_POST['id'] ?? null;

    if (!$id) {
        $response['status'] = 'error';
        $response['message'] = 'Missing suara_kebutuhan ID.';
        echo json_encode($response);
        exit();
    }

    $image_to_delete = null;
    $stmt_fetch_image = $conn->prepare("SELECT image_url FROM suara_kebutuhan WHERE id = ?");
    if ($stmt_fetch_image) {
        $stmt_fetch_image->bind_param("i", $id);
        $stmt_fetch_image->execute();
        $result_fetch_image = $stmt_fetch_image->get_result();
        if ($row = $result_fetch_image->fetch_assoc()) {
            $image_to_delete = $row['image_url'];
        }
        $stmt_fetch_image->close();
    }

    $stmt = $conn->prepare("DELETE FROM suara_kebutuhan WHERE id = ?");
    if ($stmt) {
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) {
            if ($image_to_delete && file_exists($image_to_delete)) {
                unlink($image_to_delete);
            }
            $response['status'] = 'success';
            $response['message'] = 'Suara kebutuhan deleted successfully.';
        } else {
            $response['status'] = 'error';
            $response['message'] = 'Failed to delete suara kebutuhan: ' . $stmt->error;
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
