from datetime import datetime, timedelta


from datetime import datetime, timedelta


def generate_slots(start_time: str, end_time: str, duration: int):
    slots = []

    current = datetime.strptime(start_time, "%H:%M")
    end = datetime.strptime(end_time, "%H:%M")

    lunch_start = datetime.strptime("13:00", "%H:%M")
    lunch_end = datetime.strptime("14:00", "%H:%M")

    while current + timedelta(minutes=duration) <= end:

        # Skip lunch break
        if lunch_start <= current < lunch_end:
            current = lunch_end
            continue

        slot_start = current.strftime("%H:%M")
        slot_end = (
            current + timedelta(minutes=duration)
        ).strftime("%H:%M")

        slots.append({
            "start": slot_start,
            "end": slot_end
        })

        current += timedelta(minutes=duration)

    return slots