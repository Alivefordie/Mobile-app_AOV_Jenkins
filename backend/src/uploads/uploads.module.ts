import { Module } from '@nestjs/common';
import { UploadsController } from './uploads.controller';
import { R2Provider } from './storage/r2.provider';
import { UploadsService } from './uploads.service';

@Module({
  controllers: [UploadsController],
  providers: [R2Provider, UploadsService],
})
export class UploadsModule {}
