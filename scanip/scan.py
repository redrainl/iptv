import asyncio
import time
import subprocess

# ===================== 配置区 =====================
TARGET_FILE = "ips_Shanghai"
OUTPUT_OK = "alive.txt"
TIMEOUT = 2.0
MAX_CONCURRENT = 2500
PROGRESS_INTERVAL = 5.0   # 每5秒刷新一次进度
# =================================================

def get_file_line_count(filepath: str) -> int:
    result = subprocess.run(
        ["wc", "-l", filepath],
        capture_output=True,
        text=True
    )
    line_num = int(result.stdout.split()[0])
    return line_num


async def check_port(ip: str, port: int, sem: asyncio.Semaphore):
    async with sem:
        try:
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection(ip, port),
                timeout=TIMEOUT
            )
            writer.close()
            await writer.wait_closed()
            return f"{ip}:{port}"
        except Exception:
            return None


async def task_consumer(line: str, sem: asyncio.Semaphore):
    line = line.strip()
    if not line:
        return None
    try:
        ip, port_str = line.split(":")
        port = int(port_str)
    except ValueError:
        return None
    return await check_port(ip, port, sem)


async def progress_reporter(total_count, shared_state):
    """独立定时协程：每5秒打印进度"""
    start_time = shared_state["start_time"]
    while not shared_state["done"]:
        count_total = shared_state["count_total"]
        count_alive = shared_state["count_alive"]
        elapsed = time.time() - start_time
        speed = count_total / elapsed if elapsed > 0 else 0
        pct = round((count_total / total_count) * 100, 2)
        remain_sec = (total_count - count_total) / speed if speed > 0 else 0
        remain_h = round(remain_sec / 3600, 2)

        print(
            f"【定时进度】{count_total}/{total_count} ({pct}%) | 存活:{count_alive} | 速率:{speed:.2f}/s | 预估剩余:{remain_h}h",
            flush=True
        )
        await asyncio.sleep(PROGRESS_INTERVAL)


async def main():
    print(f"正在调用 wc -l 统计 {TARGET_FILE} 行数...", flush=True)
    total_count = get_file_line_count(TARGET_FILE)
    print(f"目标总数：{total_count}，开始扫描！\n", flush=True)

    semaphore = asyncio.Semaphore(MAX_CONCURRENT)
    success_fp = open(OUTPUT_OK, "a", encoding="utf-8")

    # 共享状态，用于定时任务读取
    shared_state = {
        "count_total": 0,
        "count_alive": 0,
        "start_time": time.time(),
        "done": False
    }

    # 启动定时进度打印协程
    reporter_task = asyncio.create_task(progress_reporter(total_count, shared_state))

    tasks = []
    with open(TARGET_FILE, "r", encoding="utf-8") as f:
        for raw_line in f:
            shared_state["count_total"] += 1
            task = asyncio.create_task(task_consumer(raw_line, semaphore))
            tasks.append(task)

            if len(tasks) >= MAX_CONCURRENT * 3:
                done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
                tasks = list(pending)
                for d in done:
                    res = await d
                    if res:
                        shared_state["count_alive"] += 1
                        success_fp.write(res + "\n")
                        success_fp.flush()

        # 处理剩余任务
        if tasks:
            results = await asyncio.gather(*tasks)
            for res in results:
                if res:
                    shared_state["count_alive"] += 1
                    success_fp.write(res + "\n")

    success_fp.close()
    shared_state["done"] = True
    await reporter_task  # 等待进度协程退出

    total_cost = time.time() - shared_state["start_time"]
    final_pct = round((shared_state["count_total"] / total_count) * 100, 2)
    print("="*70, flush=True)
    print(f"扫描结束 | 总条目：{shared_state['count_total']}/{total_count} ({final_pct}%)", flush=True)
    print(f"开放端口数量：{shared_state['count_alive']}", flush=True)
    print(f"总耗时：{round(total_cost / 3600, 2)} h", flush=True)
    print(f"平均速度：{round(shared_state['count_total'] / total_cost, 2)} 条/秒", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
