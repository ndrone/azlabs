package org.example.azpipelines;

import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;

@SpringBootTest
class AzPipelinesApplicationTests
{
    @Autowired
    private ApplicationContext applicationContext;

    @Test
    void contextLoads()
    {
        Assertions.assertThat(applicationContext.getBean(HelloController.class)).isNotNull();
    }

}
