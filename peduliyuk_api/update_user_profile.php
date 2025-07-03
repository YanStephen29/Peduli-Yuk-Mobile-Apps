<?php
include 'db.php';

header('Content-Type: application/json; charset=UTF-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode permintaan tidak diizinkan.']);
    exit();
}

$userId = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;

if ($userId <= 0) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'ID Pengguna tidak diberikan atau tidak valid.']);
    exit();
}

$username = $_POST['username'] ?? null;
$address = $_POST['address'] ?? null;
$noTelp = $_POST['no_telp'] ?? null;
$age = isset($_POST['age']) && is_numeric($_POST['age']) ? intval($_POST['age']) : null;
$photoPath = null;

if (isset($_FILES['photo']) && $_FILES['photo']['error'] === UPLOAD_ERR_OK) {
    $uploadDir = 'assets/uploads/'; 
    
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }

    $fileExtension = pathinfo($_FILES["photo"]["name"], PATHINFO_EXTENSION);
    $fileName = "user_" . $userId . "_" . time() . "." . $fileExtension;
    $targetFile = $uploadDir . $fileName;
    $dbPath = $uploadDir . $fileName;

    if (move_uploaded_file($_FILES['photo']['tmp_name'], $targetFile)) {
        $photoPath = $dbPath;
    } else {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan file yang diunggah. Periksa izin folder.']);
        exit();
    }
}


$conn->begin_transaction();

try {
    $updateFieldsUsers = [];
    $bindTypesUsers = '';
    $bindParamsUsers = [];

    if ($username !== null) {
        $updateFieldsUsers[] = "username = ?";
        $bindTypesUsers .= 's';
        $bindParamsUsers[] = $username;
    }
    if ($noTelp !== null) {
        $updateFieldsUsers[] = "no_telp = ?";
        $bindTypesUsers .= 's';
        $bindParamsUsers[] = $noTelp;
    }
    if ($photoPath !== null) {
        $updateFieldsUsers[] = "photo = ?";
        $bindTypesUsers .= 's';
        $bindParamsUsers[] = $photoPath;
    }
    if (!empty($updateFieldsUsers)) {
        $sqlUsers = "UPDATE users SET " . implode(", ", $updateFieldsUsers) . " WHERE id = ?";
        $bindTypesUsers .= 'i';
        $bindParamsUsers[] = $userId;
        
        $stmtUsers = $conn->prepare($sqlUsers);
        $stmtUsers->bind_param($bindTypesUsers, ...$bindParamsUsers);

        if (!$stmtUsers->execute()) {
            throw new Exception("Gagal memperbarui tabel users: " . $stmtUsers->error);
        }
        $stmtUsers->close();
    }

    if ($address !== null || $age !== null) {
        $sqlMasyarakat = "INSERT INTO masyarakat (user_id, address, age) VALUES (?, ?, ?)
                          ON DUPLICATE KEY UPDATE address = VALUES(address), age = VALUES(age)";
        
        $stmtMasyarakat = $conn->prepare($sqlMasyarakat);
        $stmtMasyarakat->bind_param("isi", $userId, $address, $age);

        if (!$stmtMasyarakat->execute()) {
            throw new Exception("Gagal memperbarui tabel masyarakat: " . $stmtMasyarakat->error);
        }
        $stmtMasyarakat->close();
    }

    $conn->commit();
    echo json_encode(['status' => 'success', 'message' => 'Profil berhasil diperbarui!']);

} catch (Exception $e) {
    $conn->rollback();
    http_response_code(500);
    error_log("Update Profile Error: " . $e->getMessage());
    echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui profil: ' . $e->getMessage()]);
}

$conn->close();
?>