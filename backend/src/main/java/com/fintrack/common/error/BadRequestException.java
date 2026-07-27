package com.fintrack.common.error;

public class BadRequestException extends ApiException {

    public BadRequestException(String message) {
        super(400, "Bad request", message);
    }
}
