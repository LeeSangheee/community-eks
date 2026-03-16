// Comment.java
package com.example;

import java.sql.Timestamp;

public class Comment {
    public long id;
    public long postId;
    public Long authorId;
    public String authorName;
    public String content;
    public Timestamp createdAt;
}