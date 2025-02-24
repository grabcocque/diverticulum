use std::io::prelude::*;
use std::sync::{Arc, Mutex};

struct ResourceGuard<T: Send> {
    resource: Arc<Mutex<Option<T>>>,
    semaphore: Arc<tokio::sync::Semaphore>,
}

impl<T: Send> ResourceGuard<T> {
    fn new(resource: T) -> Self {
        ResourceGuard {
            resource: Arc::new(Mutex::new(Some(resource))),
            semaphore: Arc::new(tokio::sync::Semaphore::new(1)),
        }
    }

    async fn with_resource<F, R>(&self, f: F) -> R
    where
        F: FnOnce(&mut T) -> R + Send + 'static,
        R: Send + 'static,
    {
        let permit = self.semaphore.acquire().await.unwrap();
        let mut guard = self.resource.lock().unwrap();
        let resource = guard.as_mut().unwrap();
        let result = f(resource);
        drop(guard);
        drop(permit);
        result
    }
}

#[tokio::main(flavor = "multi_thread", worker_threads = 10)]
async fn main() {
    let file = std::io::stdout();
    let resource_guard = Arc::new(ResourceGuard::new(file));

    let handles: Vec<_> = (0..9)
        .map(|i| {
            let monad = resource_guard.clone();
            tokio::spawn(async move {
                monad
                    .with_resource(move |f| {
                        writeln!(f, "Hello from thread {}", i).unwrap();
                    })
                    .await
            })
        })
        .collect();

    for handle in handles {
        handle.await.unwrap();
    }
}
