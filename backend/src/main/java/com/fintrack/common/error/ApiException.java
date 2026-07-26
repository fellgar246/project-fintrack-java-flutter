package com.fintrack.common.error;

// Base exception for API errors. Subclasses define specific HTTP status codes and titles.
public abstract class ApiException extends RuntimeException {

    private final int status;
    private final String title;

    public ApiException(int status, String title, String message) {
        super(message);
        this.status = status;
        this.title = title;
    }

    public ApiException(int status, String title, String message, Throwable cause) {
        super(message, cause);
        this.status = status;
        this.title = title;
    }

    public int getStatus() {
        return status;
    }

    public String getTitle() {
        return title;
    }
}
