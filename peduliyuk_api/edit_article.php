<?php
include 'db.php';

header('Content-Type: application/json');

$response = array();

$conn->begin_transaction();

try {
    $id = $_POST['id'] ?? null;
    $title = $_POST['title'] ?? null;
    $description = $_POST['description'] ?? null;
    $source_link = $_POST['source_link'] ?? null;
    $categories_json = $_POST['categories'] ?? '[]';

    $categories = json_decode($categories_json, true);

    if (empty($id) || empty($title) || empty($description)) {
        throw new Exception("ID artikel, judul, atau deskripsi tidak boleh kosong.");
    }

    $current_image_url = '';
    $stmt_fetch_old_image = $conn->prepare("SELECT image_url FROM articles WHERE id = ?");
    $stmt_fetch_old_image->bind_param("i", $id);
    $stmt_fetch_old_image->execute();
    $result_old_image = $stmt_fetch_old_image->get_result();
    if ($row = $result_old_image->fetch_assoc()) {
        $current_image_url = $row['image_url'];
    }
    $stmt_fetch_old_image->close();


    $image_url_to_save = $current_image_url;

    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $target_dir = "assets/uploads/";

        if (!is_dir($target_dir)) {
            if (!mkdir($target_dir, 0777, true)) {
                throw new Exception('Gagal membuat direktori upload: ' . error_get_last()['message']);
            }
        }

        $filename = basename($_FILES['image']['name']);
        $file_extension = pathinfo($filename, PATHINFO_EXTENSION);
        $allowed_extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'];
        if (!in_array(strtolower($file_extension), $allowed_extensions)) {
            throw new Exception('Tipe file tidak diizinkan. Hanya ' . implode(', ', $allowed_extensions) . '.');
        }

        $new_file_name = uniqid('article_') . '.' . $file_extension;
        $target_file_path = $target_dir . $new_file_name;

        if (move_uploaded_file($_FILES['image']['tmp_name'], $target_file_path)) {
            $image_url_to_save = $target_file_path;

            if ($current_image_url && file_exists($current_image_url) && !str_contains($current_image_url, 'placeholder.jpg')) {
                 unlink($current_image_url);
            }
        } else {
            throw new Exception('Gagal mengunggah gambar baru: Error ' . $_FILES['image']['error']);
        }
    }

    $stmt_update_article = $conn->prepare("UPDATE articles SET title = ?, description = ?, source_link = ?, image_url = ? WHERE id = ?");
    $stmt_update_article->bind_param("ssssi", $title, $description, $source_link, $image_url_to_save, $id);

    if (!$stmt_update_article->execute()) {
        throw new Exception("Gagal memperbarui data artikel: " . $stmt_update_article->error);
    }
    $stmt_update_article->close();

    $stmt_delete_categories = $conn->prepare("DELETE FROM article_categories WHERE article_id = ?");
    $stmt_delete_categories->bind_param("i", $id);
    if (!$stmt_delete_categories->execute()) {
        throw new Exception("Gagal menghapus kategori lama: " . $stmt_delete_categories->error);
    }
    $stmt_delete_categories->close();

    if (!empty($categories)) {
        $insert_category_query = "INSERT INTO article_categories (article_id, category_id) VALUES ";
        $values = [];
        $types = "";
        foreach ($categories as $cat_id) {
            $values[] = $id;
            $values[] = $cat_id;
            $insert_category_query .= "(?,?),";
            $types .= "ii";
        }
        $insert_category_query = rtrim($insert_category_query, ",");

        $stmt_insert_categories = $conn->prepare($insert_category_query);
        $stmt_insert_categories->bind_param($types, ...$values);

        if (!$stmt_insert_categories->execute()) {
            throw new Exception("Gagal menambahkan kategori baru: " . $stmt_insert_categories->error);
        }
        $stmt_insert_categories->close();
    }

    $conn->commit();
    $response['status'] = 'success';
    $response['message'] = 'Artikel berhasil diperbarui.';

} catch (Exception $e) {
    $conn->rollback();
    $response['status'] = 'error';
    $response['message'] = $e->getMessage();
}

echo json_encode($response);
$conn->close();
?>