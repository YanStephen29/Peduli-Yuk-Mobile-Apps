<?php
include 'db.php';

header('Content-Type: application/json');

$articleId = isset($_GET['articleId']) ? (int)$_GET['articleId'] : 0;
$categoryNamesParam = isset($_GET['categoryIds']) ? $_GET['categoryIds'] : '';

$data = [];

if (!empty($categoryNamesParam)) {
    $categoryNames = explode(',', $categoryNamesParam);
    $categoryNames = array_map('trim', $categoryNames);

    if (empty($categoryNames)) {
        echo json_encode(['status' => 'success', 'articles' => [], 'message' => 'No valid category names provided']);
        $conn->close();
        exit();
    }

    try {
        $placeholdersNames = implode(',', array_fill(0, count($categoryNames), '?'));
        $queryGetCategoryIds = "SELECT id FROM categories WHERE name IN ($placeholdersNames)";
        $stmtGetCategoryIds = $conn->prepare($queryGetCategoryIds);

        if (!$stmtGetCategoryIds) {
            echo json_encode(['status' => 'error', 'message' => 'Failed to prepare category ID statement: ' . $conn->error]);
            $conn->close();
            exit();
        }

        $typesNames = str_repeat('s', count($categoryNames));
        $stmtGetCategoryIds->bind_param($typesNames, ...$categoryNames);
        $stmtGetCategoryIds->execute();
        $resultCategoryIds = $stmtGetCategoryIds->get_result();

        $categoryIds = [];
        while ($row = $resultCategoryIds->fetch_assoc()) {
            $categoryIds[] = $row['id'];
        }
        $stmtGetCategoryIds->close();

        if (empty($categoryIds)) {
            echo json_encode(['status' => 'success', 'articles' => [], 'message' => 'No matching category IDs found for provided names']);
            $conn->close();
            exit();
        }

        $placeholdersIds = implode(',', array_fill(0, count($categoryIds), '?'));

        $query = "
            SELECT DISTINCT a.id, a.title, a.image_url, a.description, a.created_at, a.source_link
            FROM articles a
            INNER JOIN article_categories ac ON a.id = ac.article_id
            WHERE a.id != ?
            AND ac.category_id IN ($placeholdersIds)
            ORDER BY a.created_at DESC
            LIMIT 5
        ";

        $stmt = $conn->prepare($query);

        if (!$stmt) {
            echo json_encode(['status' => 'error', 'message' => 'Failed to prepare articles statement: ' . $conn->error]);
            $conn->close();
            exit();
        }

        $types = 'i' . str_repeat('i', count($categoryIds));
        $params = array_merge([$articleId], $categoryIds);

        $stmt->bind_param($types, ...$params);
        $stmt->execute();
        $result = $stmt->get_result();

        $articles = [];
        while ($row = $result->fetch_assoc()) {
            $articles[] = $row;
        }

        $stmt->close();

        echo json_encode([
            'status' => 'success',
            'articles' => $articles
        ]);

    } catch (Exception $e) {
        echo json_encode(['status' => 'error', 'message' => 'Database error: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['status' => 'success', 'articles' => [], 'message' => 'No category names provided, returning empty list']);
}

$conn->close();
?>