<?php
include 'db.php';
header("Content-Type: application/json; charset=UTF-8");

if (isset($_POST['email'], $_POST['password'], $_POST['role'], $_POST['username'], $_POST['no_telp'])) {
    $email = $_POST['email'];
    $password = password_hash($_POST['password'], PASSWORD_DEFAULT);
    $role = $_POST['role'];
    $username = $_POST['username'];
    $no_telp = $_POST['no_telp'];

    $conn->begin_transaction();

    try {
        $stmt = $conn->prepare("INSERT INTO users (email, password, role, username, no_telp) VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("sssss", $email, $password, $role, $username, $no_telp);
        $stmt->execute();
        $user_id = $stmt->insert_id;

        if ($role == 'masyarakat') {
            if (isset($_POST['age'], $_POST['address'])) {
                $age = $_POST['age'];
                $address = $_POST['address'];
                $stmt = $conn->prepare("INSERT INTO masyarakat (user_id, age, address) VALUES (?, ?, ?)");
                $stmt->bind_param("iis", $user_id, $age, $address);
                $stmt->execute();
            } else {
                throw new Exception("Data usia atau alamat masyarakat tidak ditemukan.");
            }
        } elseif ($role == 'lembaga_sosial' || $role == 'umkm') {
            if (isset($_POST['organization_name'], $_POST['address'], $_POST['position_id'])) {
                $organization_name = $_POST['organization_name'];
                $address = $_POST['address'];
                $position_id = $_POST['position_id'];
                if ($role == 'lembaga_sosial') {
                    $stmt = $conn->prepare("INSERT INTO lembaga_sosial (user_id, organization_name, address, position_id) VALUES (?, ?, ?, ?)");
                } else {
                    $stmt = $conn->prepare("INSERT INTO umkm (user_id, organization_name, address, position_id) VALUES (?, ?, ?, ?)");
                }
                $stmt->bind_param("issi", $user_id, $organization_name, $address, $position_id);
                $stmt->execute();
            } else {
                throw new Exception("Data organisasi, alamat, atau posisi tidak ditemukan.");
            }
        }

        $conn->commit();
        echo json_encode(["status" => "success"]);

    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }

    $conn->close();
} else {
    echo json_encode(["status" => "error", "message" => "Data pendaftaran tidak lengkap."]);
}
?>