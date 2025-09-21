-- AlterTable
ALTER TABLE "event_data" ADD COLUMN     "client_user_id" VARCHAR(255);

-- AlterTable
ALTER TABLE "revenue" ADD COLUMN     "client_user_id" VARCHAR(255);

-- AlterTable
ALTER TABLE "website_event" ADD COLUMN     "client_user_id" VARCHAR(255);
