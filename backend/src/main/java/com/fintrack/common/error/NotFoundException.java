package com.fintrack.common.error;

public class NotFoundException extends ApiException {

  public NotFoundException(String message) {
    super(404, "Resource not found", message);
  }
}
