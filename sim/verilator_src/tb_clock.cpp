
#include <cassert>
#include <cstdint>
class tb_clock
{
private:
    uint64_t increment_ps;
    uint64_t current_time_ps;
    uint64_t last_posedge_ps;
    uint64_t ticks;

public:

    tb_clock() = default;

    uint64_t get_time_to_edge (void) const {
        // next edge is a negative edge
        if (last_posedge_ps + increment_ps > current_time_ps) {
            return last_posedge_ps + increment_ps - current_time_ps;
        }
        else {
            // next edge is a positive edge
            return last_posedge_ps + 2 * increment_ps - current_time_ps;
        }
    }

    void init (uint64_t increment_ps) {
        this->increment_ps = increment_ps/2;
        current_time_ps = increment_ps + 1;
        last_posedge_ps = 0;
    }

    void set_period_ps(uint64_t period_ps) {
        this->increment_ps = period_ps/2;
    }

    void set_freq_hz(uint64_t freq_hz) {
        uint64_t period_ps = 1e12 / (double)(freq_hz);
        this->increment_ps = ((uint64_t) period_ps)/2;
    }

    int advance(uint64_t time)
    {
        assert(time <= this->increment_ps);
        current_time_ps += time;

        // check in what phase the clock is currently in
        if (current_time_ps >= (last_posedge_ps + 2 * increment_ps)) {
            // positive half
            last_posedge_ps += 2*increment_ps;
            ++ticks;
            return 1;
        } else if (current_time_ps >= (last_posedge_ps + increment_ps)) {
            // negative half
            return 0;
        } else {
            // positive half
            return 1;
        }
    }

    uint64_t get_period_ps(void) {
        return this->increment_ps*2;
    }

    bool is_rising_edge(void)
    {
        return (current_time_ps == last_posedge_ps);
    }

    bool is_falling_edge(void)
    {
        return (current_time_ps == (last_posedge_ps + increment_ps));
    }
};