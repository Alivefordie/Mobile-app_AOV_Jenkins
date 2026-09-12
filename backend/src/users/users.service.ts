import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole, UserStatus } from './entities/user.entity';

export interface CreateUserInput {
  email: string;
  passwordHash: string;
  displayName: string;
  avatarUrl?: string | null;
  role?: UserRole;
}

export interface UpdateUserInput {
  email?: string;
  displayName?: string;
  avatarUrl?: string | null;
  role?: UserRole;
  status?: UserStatus;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  findAll(): Promise<User[]> {
    return this.userRepository.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) throw new NotFoundException(`User with id ${id} not found`);
    return user;
  }

  findById(id: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { id } });
  }

  findByEmail(email: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email: email.toLowerCase() },
    });
  }

  /** ใช้ตอน login เท่านั้น เพราะ passwordHash เป็นคอลัมน์ select: false */
  findByEmailWithPassword(email: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email: email.toLowerCase() },
      select: {
        id: true,
        email: true,
        passwordHash: true,
        displayName: true,
        avatarUrl: true,
        role: true,
        status: true,
      },
    });
  }

  async create(input: CreateUserInput): Promise<User> {
    const user = await this.userRepository.save(
      this.userRepository.create({
        ...input,
        email: input.email.toLowerCase(),
      }),
    );
    return this.findOne(user.id);
  }

  async update(id: string, input: UpdateUserInput): Promise<User> {
    const user = await this.findOne(id);
    Object.assign(user, input, { id: user.id });
    await this.userRepository.save(user);
    return this.findOne(user.id);
  }

  async remove(id: string): Promise<void> {
    const user = await this.findOne(id);
    await this.userRepository.remove(user);
  }
}
