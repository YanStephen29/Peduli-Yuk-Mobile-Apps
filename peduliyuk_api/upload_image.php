<?php
error_reporting(0);
ini_set('display_errors', 0);

header('Content-Type: application/json');

$response = array();
$upload_dir = 'assets/uploads/';
$base_url = 'http://192.168.192.247/peduliyuk_api/';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($_FILES['image'])) {
    $image_file = $_FILES['image'];

    if (!is_dir($upload_dir)) {
        if (!mkdir($upload_dir, 0777, true)) {
            $response['status'] = 'error';
            $response['message'] = 'Gagal membuat folder upload: Pastikan izin direkori induk benar.';
            echo json_encode($response);
            exit();
        }
    }

    $allowed_mime_types = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
        'image/heic',
        'image/heif',
        'application/octet-stream'
    ];

    $allowed_extensions = [
        'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'
    ];

    $max_size = 100 * 1024 * 1024;

    $detected_mime_type = $image_file['type'];
    $file_extension = strtolower(pathinfo($image_file['name'], PATHINFO_EXTENSION));

    $is_allowed_mime = in_array($detected_mime_type, $allowed_mime_types);
    $is_allowed_extension = in_array($file_extension, $allowed_extensions);

    $is_valid_file_type = $is_allowed_mime && ($detected_mime_type !== 'application/octet-stream' || $is_allowed_extension);

    if (!$is_valid_file_type) {
        $response['status'] = 'error';
        $response['message'] = 'Tipe file tidak diizinkan. Deteksi: "' . $detected_mime_type . '" (.' . $file_extension . '). Hanya JPEG, PNG, GIF, WEBP, HEIC, HEIF.';
    } elseif ($image_file['size'] > $max_size) {
        $response['status'] = 'error';
        $response['message'] = 'Ukuran file terlalu besar. Maksimal 5MB.';
    } else {
        $new_file_name = uniqid('img_') . '.' . $file_extension;
        $target_file = $upload_dir . $new_file_name;
        if (move_uploaded_file($image_file['tmp_name'], $target_file)) {
            $response['image_url'] = $target_file;
            $response['status'] = 'success';
            $response['message'] = 'Gambar berhasil diunggah.';
        } else {
            $response['status'] = 'error';
            $error_code = $image_file['error'];
            $php_error_msg = '';
            $last_error = error_get_last();
            if ($last_error && $last_error['type'] === E_WARNING && strpos($last_error['message'], 'move_uploaded_file') !== false) {
                $php_error_msg = ' (PHP Warning: ' . $last_error['message'] . ')';
            }

            $response['message'] = 'Gagal mengunggah gambar. Error code: ' . $error_code . '. Pastikan folder "assets/uploads" ada dan memiliki izin tulis.' . $php_error_msg;
        }
    }
} else {
    $response['status'] = 'error';
    $response['message'] = 'Tidak ada file gambar yang diunggah atau metode request tidak diizinkan.';
}

echo json_encode($response);
?>