<?php declare(strict_types=1);

/* Copyright (c) 2022 - Daniel Weise <daniel.weise@concepts-and-training.de> - Extended GPL, see LICENSE */

namespace CaT\Doil\Commands\Repo;

use RuntimeException;
use PHPUnit\Framework\TestCase;
use CaT\Doil\Lib\ConsoleOutput\Writer;
use CaT\Doil\Lib\ConsoleOutput\CommandWriter;
use Symfony\Component\Console\Tester\CommandTester;

class UpdateCommandTest extends TestCase
{
    public function test_execute_without_name() : void
    {
        $repo_manager = $this->createMock(RepoManager::class);
        $writer = new CommandWriter();

        $command = new UpdateCommand($repo_manager, $writer);
        $tester = new CommandTester($command);

        $this->expectException(RuntimeException::class);
        $tester->execute([]);
    }

    public function test_execute_with_empty_name() : void
    {
        $repo_manager = $this->createMock(RepoManager::class);
        $writer = new CommandWriter();

        $command = new UpdateCommand($repo_manager, $writer);
        $tester = new CommandTester($command);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage("Name of the repo cannot be empty!");
        $tester->execute(["name" => ""]);
    }

    public function test_execute_with_wrong_chars_in_name() : void
    {
        $repo_manager = $this->createMock(RepoManager::class);
        $writer = new CommandWriter();

        $command = new UpdateCommand($repo_manager, $writer);
        $tester = new CommandTester($command);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage("Invalid characters! Only letters, numbers and underscores are allowed!");
        $tester->execute(["name" => "324$34"]);
    }

    public function test_execute_with_non_existing_repo() : void
    {
        $repo_manager = $this->createMock(RepoManager::class);
        $writer = new CommandWriter();

        $command = new UpdateCommand($repo_manager, $writer);
        $tester = new CommandTester($command);

        $repo_manager
            ->expects($this->once())
            ->method("getEmptyRepo")
            ->willReturn(new Repo())
        ;
        $repo = new Repo("doil");
        $repo_manager
            ->expects($this->once())
            ->method("repoExists")
            ->with($repo)
            ->willReturn(false)
        ;

        $execute_result = $tester->execute(["name" => "doil"]);
        $output = $tester->getDisplay(true);

        $result = "Error:\n\tRepository doil does not exists!\n\tUse doil repo:list to see current installed repos.\n";
        $this->assertEquals($result, $output);
        $this->assertEquals(1, $execute_result);
    }

    public function test_execute() : void
    {
        $repo_manager = $this->createMock(RepoManager::class);
        $writer = $this->createMock(Writer::class);

        $command = new UpdateCommand($repo_manager, $writer);
        $tester = new CommandTester($command);

        $repo_manager
            ->expects($this->once())
            ->method("getEmptyRepo")
            ->willReturn(new Repo())
        ;
        $repo = new Repo("doil");
        $repo_manager
            ->expects($this->once())
            ->method("repoExists")
            ->with($repo)
            ->willReturn(true)
        ;
        $repo_manager
            ->expects($this->once())
            ->method("updateRepo")
            ->with($repo)
        ;

        $execute_result = $tester->execute(["name" => "doil"]);
        $this->assertEquals(0, $execute_result);
    }
}