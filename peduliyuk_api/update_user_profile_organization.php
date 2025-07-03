<?php
include 'db.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['status' => 'error', 'message' => 'Invalid request method. Only POST is allowed.']);
    exit;
}

$user_id = $_POST['user_id'] ?? null;
$username = $_POST['username'] ?? null;
$no_telp = $_POST['no_telp'] ?? null;
$role = $_POST['role'] ?? null;
$organization_name = $_POST['organization_name'] ?? null;
$address = $_POST['address'] ?? null;

if (!$user_id || !$username || !$role) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required user parameters.']);
    exit;
}

$user_id = $conn->real_escape_string($user_id);
$username = $conn->real_escape_string($username);
$no_telp = $conn->real_escape_string($no_telp);
$role = $conn->real_escape_string($role);
$organization_name_db = $conn->real_escape_string($organization_name);
$address_db = $conn->real_escape_string($address);

$photo_path = null;
$upload_dir = 'uploads/user_photos/';
if (!is_dir($upload_dir)) {
    mkdir($upload_dir, 0777, true);
}

if (isset($_FILES['photo']) && $_FILES['photo']['error'] == UPLOAD_ERR_OK) {
    $file_tmp_name = $_FILES['photo']['tmp_name'];
    $file_extension = pathinfo($_FILES['photo']['name'], PATHINFO_EXTENSION);
    $file_name = 'user_' . $user_id . '_' . time() . '.' . $file_extension;
    $destination = $upload_dir . $file_name;

    if (move_uploaded_file($file_tmp_name, $destination)) {
        $photo_path = $destination;
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to move uploaded photo file.']);
        exit;
    }
} else if (isset($_POST['current_photo']) && !empty($_POST['current_photo'])) {
    $photo_path = $conn->real_escape_string($_POST['current_photo']);
}

$conn->begin_transaction();

try {
    $sql_user = "UPDATE users SET username = ?, no_telp = ?";
    $bind_params_user = "ss";
    $bind_values_user = [&$username, &$no_telp];

    if ($photo_path !== null) {
        $sql_user .= ", photo = ?";
        $bind_params_user .= "s";
        $bind_values_user[] = &$photo_path;
    }
    $sql_user .= " WHERE id = ?";
    $bind_params_user .= "i";
    $bind_values_user[] = &$user_id;

    $stmt_user = $conn->prepare($sql_user);
    $stmt_user->bind_param($bind_params_user, ...$bind_values_user);
    $stmt_user->execute();
    $user_affected_rows = $stmt_user->affected_rows;

    $specific_affected_rows = 0;
    $role_lower = strtolower($role);

    $table_specific = "";
    if ($role_lower === 'umkm' || $role_lower === 'lembaga_sosial') {
        $table_specific = ($role_lower === 'umkm') ? 'umkm' : 'lembaga_sosial';
        $sql_specific = "UPDATE $table_specific SET organization_name = ?, address = ? WHERE user_id = ?";
        $stmt_specific = $conn->prepare($sql_specific);
        $stmt_specific->bind_param("ssi", $organization_name_db, $address_db, $user_id);
        $stmt_specific->execute();
        $specific_affected_rows = $stmt_specific->affected_rows;
    } elseif ($role_lower === 'masyarakat') {
        $sql_specific = "UPDATE masyarakat SET address = ? WHERE user_id = ?";
        $stmt_specific = $conn->prepare($sql_specific);
        $stmt_specific->bind_param("si", $address_db, $user_id);
        $stmt_specific->execute();
        $specific_affected_rows = $stmt_specific->affected_rows;
    }

    if ($user_affected_rows > 0 || $specific_affected_rows > 0) {
        $conn->commit();
        echo json_encode(['status' => 'success', 'message' => 'Profile updated successfully.', 'photo_path' => $photo_path]);
    } else {
        $conn->rollback();
        echo json_encode(['status' => 'error', 'message' => 'No changes were made.']);
    }

} catch (Exception $e) {
    $conn->rollback();
    error_log("Profile update failed: " . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'Failed to update profile: ' . $e->getMessage()]);
}

$conn->close();
?>