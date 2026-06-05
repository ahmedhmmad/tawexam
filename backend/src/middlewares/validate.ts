import type { NextFunction, Request, Response } from "express";
import type { AnyZodObject, ZodEffects, ZodObject } from "zod";

type Schema = AnyZodObject | ZodObject<any> | ZodEffects<any>;

export function validateBody(schema: Schema) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    req.body = schema.parse(req.body);
    next();
  };
}

export function validateQuery(schema: Schema) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    req.query = schema.parse(req.query);
    next();
  };
}

export function validateParams(schema: Schema) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    req.params = schema.parse(req.params);
    next();
  };
}

