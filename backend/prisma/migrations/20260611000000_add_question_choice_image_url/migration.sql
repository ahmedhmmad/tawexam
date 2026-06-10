-- Add nullable image support to questions and choices (backward compatible)
ALTER TABLE "Question" ADD COLUMN "imageUrl" TEXT;
ALTER TABLE "Choice" ADD COLUMN "imageUrl" TEXT;
