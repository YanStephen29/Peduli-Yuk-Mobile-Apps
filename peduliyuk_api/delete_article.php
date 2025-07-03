<?php
include 'db.php';

$id = $_POST['id'] ?? null;

if ($id) {
    $stmt = $conn->prepare("SELECT image_url FROM articles WHERE id = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $stmt->store_result();
    $stmt->bind_result($image_url);

    if ($stmt->fetch()) {
        if (!empty($image_url) && file_exists($image_url)) {
            unlink($image_url);
        }
    }

    $delete_stmt = $conn->prepare("DELETE FROM articles WHERE id = ?");
    $delete_stmt->bind_param("i", $id);
    $delete_stmt->execute();

    if ($delete_stmt->affected_rows > 0) {
        $delete_categories_stmt = $conn->prepare("DELETE FROM article_categories WHERE article_id = ?");
        $delete_categories_stmt->bind_param("i", $id);
        $delete_categories_stmt->execute();

        echo json_encode(['status' => 'success']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Article not found']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Missing ID']);
}

$conn->close();
?>
