package com.fintrack.common.error;

public class BusinessRuleException extends ApiException {

  public BusinessRuleException(String message) {
    super(422, "Business rule violation", message);
  }
}
