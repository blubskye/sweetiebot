package sweetiebot

import (
	"sync"
	"sync/atomic"
	"time"
)

// AtomicFlag represents an atomic bit that can be set or cleared
// Kept for backwards compatibility with db.go statuslock
type AtomicFlag struct {
	flag uint32
}

// SaturationLimit tracks when events occured and implements a saturation limit on them
// Go 1.25 optimization: Replaced spinlock with sync.Mutex to avoid CPU-burning busy-wait
type SaturationLimit struct {
	times []int64
	index int
	lock  sync.Mutex
}

func realmod(x int, m int) int {
	x %= m
	if x < 0 {
		x += m
	}
	return x
}

func (f *AtomicFlag) test_and_set() bool {
	return atomic.SwapUint32(&f.flag, 1) != 0
}

func (f *AtomicFlag) clear() {
	atomic.SwapUint32(&f.flag, 0)
}

func (s *SaturationLimit) append(t int64) {
	s.lock.Lock()
	defer s.lock.Unlock()
	s.index = realmod(s.index+1, len(s.times))
	s.times[s.index] = t
}

// Used for our own saturation limits, where we check to see if sending the message would violate our limit BEFORE we actually send it.
func (s *SaturationLimit) check(num int, period int64, curtime int64) bool {
	s.lock.Lock()
	defer s.lock.Unlock()
	i := realmod(s.index-(num-1), len(s.times))
	return (curtime - s.times[i]) <= period
}

// Used for spam detection, where we always insert the message first (because it's already happened) and THEN check to see if it violated the limit.
func (s *SaturationLimit) checkafter(num int, period int64) bool {
	s.lock.Lock()
	defer s.lock.Unlock()
	i := realmod(s.index-num, len(s.times))
	return (s.times[s.index] - s.times[i]) <= period
}

func (s *SaturationLimit) resize(size int) {
	s.lock.Lock()
	defer s.lock.Unlock()
	n := make([]int64, size, size)
	copy(n, s.times)
	s.times = n
}

// CheckRateLimit performs a check on the rate limit without updating it
func CheckRateLimit(prevtime *int64, interval int64) bool {
	return time.Now().UTC().Unix()-atomic.LoadInt64(prevtime) > interval
}

// RateLimit checks the rate limit, returns false if it was violated, and updates the rate limit
// Go 1.25 optimization: Fixed race condition with proper atomic CAS loop
func RateLimit(prevtime *int64, interval int64) bool {
	t := time.Now().UTC().Unix()
	for {
		d := atomic.LoadInt64(prevtime)
		if t-d <= interval {
			return false
		}
		if atomic.CompareAndSwapInt64(prevtime, d, t) {
			return true
		}
		// CAS failed, another goroutine updated - retry
	}
}

// AtomicBool represents an atomic boolean that can be set to true or false
type AtomicBool struct {
	flag uint32
}

func (b *AtomicBool) get() bool {
	return atomic.LoadUint32(&b.flag) != 0
}

func (b *AtomicBool) set(value bool) {
	var v uint32 = 0
	if value {
		v = 1
	}
	atomic.StoreUint32(&b.flag, v)
}
