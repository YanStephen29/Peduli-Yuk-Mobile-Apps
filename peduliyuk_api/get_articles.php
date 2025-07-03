<?php
header('Content-Type: application/json');

require_once 'db.php';

$response = array();

try {
    $sql = "
      SELECT
        a.id,
        a.title,
        a.image_url,
        a.description,
        a.source_link,
        a.created_at,
        IFNULL(
          CONCAT('[', GROUP_CONCAT(ac.category_id ORDER BY ac.category_id ASC SEPARATOR ','), ']'),
          '[]'
        ) as category_ids
      FROM articles a
      LEFT JOIN article_categories ac ON a.id = ac.article_id
      GROUP BY a.id
      ORDER BY a.created_at DESC
    ";

    $stmt = $conn->prepare($sql);

    if (!$stmt) {
        throw new Exception("Gagal menyiapkan statement: " . $conn->error);
    }

    $stmt->execute();
    $result = $stmt->get_result();

    $articles = [];
    while ($row = $result->fetch_assoc()) {
        $row['category_ids'] = $row['category_ids'] ?? '[]';
        $articles[] = $row;
    }

    $stmt->close();

    $response['status'] = 'success';
    $response['articles'] = $articles;

} catch (Exception $e) {
    $response['status'] = 'error';
    $response['message'] = 'Database error: ' . $e->getMessage();
} finally {
    $conn->close();
}

echo json_encode($response);
?>