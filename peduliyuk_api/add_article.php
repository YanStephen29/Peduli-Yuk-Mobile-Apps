<?php
include 'db.php';

$title = $_POST['title'] ?? '';
$image_url = '';
$description = $_POST['description'] ?? '';
$source_link = $_POST['source_link'] ?? '';
$categories = json_decode($_POST['categories'] ?? '[]', true);

if (!is_array($categories)) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid categories format']);
    exit;
}

$target_dir = "assets/uploads/";
if (!file_exists($target_dir)) {
    if (!mkdir($target_dir, 0777, true)) {
        echo json_encode(['status' => 'error', 'message' => 'Failed to create upload directory']);
        exit;
    }
}

$allowed_extensions = ['jpg', 'jpeg', 'png', 'gif'];
$max_size = 100 * 1024 * 1024;

$image_url = '';
if (isset($_FILES['image']['name']) && $_FILES['image']['name']) {
    $filename = basename($_FILES['image']['name']);
    $file_extension = pathinfo($filename, PATHINFO_EXTENSION);
    if (!in_array(strtolower($file_extension), $allowed_extensions)) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid file type']);
        exit;
    }

    if ($_FILES['image']['size'] > $max_size) {
        echo json_encode(['status' => 'error', 'message' => 'File size is too large']);
        exit;
    }

    $target_file = $target_dir . uniqid() . '_' . $filename;

    if (move_uploaded_file($_FILES['image']['tmp_name'], $target_file)) {
        $image_url = $target_file;
    }
}

$query = "INSERT INTO articles (title, image_url, description, source_link) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($query);
$stmt->bind_param("ssss", $title, $image_url, $description, $source_link);
$stmt->execute();
$article_id = $stmt->insert_id;

foreach ($categories as $category_id) {
    $category_query = "INSERT INTO article_categories (article_id, category_id) VALUES (?, ?)";
    $category_stmt = $conn->prepare($category_query);
    $category_stmt->bind_param("ii", $article_id, $category_id);
    $category_stmt->execute();
}

echo json_encode(['status' => 'success']);
mysqli_close($conn);
?>
